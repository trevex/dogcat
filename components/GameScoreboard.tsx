import useSWR from 'swr';

const scoreFetcher = (score?: number) =>
    fetch('/api/scores', {
        method: score === undefined ? 'GET' : 'POST',
        cache: 'no-cache',
        headers: {
            'Content-Type': 'application/json'
        },
        body: score === undefined ? undefined : JSON.stringify({ score })
    }).then((res) => res.json());

type Score = {
    username: string,
    score: number,
    createdAt: string
};

type GameScoreboardProps = {
    score?: number
};

const GameScoreboard = ({ score }: GameScoreboardProps) => {
    const { data } = useSWR([score], scoreFetcher);
    console.log(data);
    if (data === undefined) {
        return (
            <div className="absolute inset-0 flex justify-center items-center z-10">
                <p className="text-2xl font-bold">Loading...</p>
            </div>
        )
    }

    if (data.message !== undefined) { // Something went wrong!
        return (<p>{data.message}</p>
        )
    }

    const scores = (data as any[]).map((d) => ({
        username: d.username as string,
        score: d.score as number,
        createdAt: new Date(d.createdAt),
        external: true
    }))

    return (
        <div className="absolute inset-0 flex justify-center items-center z-10">
            <p className="text-2xl font-bold">Scoreboard</p>
            <br />
            <p className="text-large">{score}</p>
            {scores.map((d) => (<p key={d.createdAt.toString()}>{d.username} - {d.score} [{d.createdAt.toString()}]</p>))}
        </div>
    );
};

export default GameScoreboard;
