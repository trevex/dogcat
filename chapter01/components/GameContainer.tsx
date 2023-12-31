import Image from 'next/image';
import { PropsWithChildren, ChangeEvent } from 'react';

import { Status, useGameContext } from "./GameProvider";
import GameScoreboard from './GameScoreboard';

import cat1 from '../public/cat-body-01.png'
import cat2 from '../public/cat-body-02.png'
import cat3 from '../public/cat-body-03.png'
import cat4 from '../public/cat-body-04.png'
import dog1 from '../public/dog-body-01.png'
import dog2 from '../public/dog-body-02.png'
import dog3 from '../public/dog-body-03.png'
import dog4 from '../public/dog-body-04.png'
import play from '../public/play.png'
import pause from '../public/pause.png'
import restart from '../public/restart.png'
import dogcat from '../public/dogcat.png'

type GameContainerProps = {
};

const GameContainer = ({ children }: PropsWithChildren<GameContainerProps>) => {
    const {
        score,
        status,
        playerName,
        startGame,
        pauseGame,
        resumeGame,
    } = useGameContext();

    const handleInputPlayerName = (event: ChangeEvent<HTMLInputElement>) => {
        if (event.target.value === "") {
            playerName.current = "anonymous";
            return
        }
        playerName.current = event.target.value;
    }

    return (
        <div className="flex flex-col items-center h-screen bg-stone-200">
            <div className="grid grid-flow-row auto-rows-max">
                <div className="flex justify-center">
                    <div>
                        <Image className="max-w-xs md:max-w-xl" alt="Logo" src={dogcat} width={405} height={90} />
                    </div>
                </div>
                <div className="flex justify-center">
                    <input className="w-48 md:w-96 p-3 text-sm border-red-200 rounded-lg" placeholder="Type in your player name" type="text" onChange={handleInputPlayerName} />
                </div>
                <div className="flex content-between">
                    <div className="grid-flow-col auto-cols-max content-end -mb-2 hidden md:grid">
                        <Image alt="Cat 1" src={cat1} width={64} height={64} />
                        <Image alt="Cat 2" src={cat2} width={64} height={64} />
                        <Image alt="Cat 3" src={cat3} width={64} height={64} />
                        <Image alt="Cat 4" src={cat4} width={64} height={64} />
                    </div>
                    <div className="m-auto">
                        <div className="transform transition duration-200 hover:sepia">
                            {status === Status.NewGame ? (
                                <a onClick={startGame}>
                                    <Image alt="Play" src={play} width={100} height={100} />
                                </a>
                            ) : status === Status.Running ? (
                                <a onClick={pauseGame}>
                                    <Image alt="Pause" src={pause} width={100} height={100} />
                                </a>
                            ) : status === Status.Paused ? (
                                <a onClick={resumeGame}>
                                    <Image alt="Play" src={play} width={100} height={100} />
                                </a>
                            ) : status === Status.Lost ? (
                                <a onClick={startGame}>
                                    <Image alt="Play" src={restart} width={100} height={100} />
                                </a>
                            ) : (
                                <a onClick={startGame}>
                                    <Image alt="Play" src={play} width={100} height={100} />
                                </a>
                            )}
                        </div>
                        <p className={`font-sans text-2xl text-center ${status === Status.Lost ? "text-red-600 font-bold" : ""}`}>Score: {score}</p>
                    </div>
                    <div className="grid-flow-col auto-cols-max content-end -mb-2 hidden md:grid">
                        <Image alt="Dog 1" src={dog1} width={64} height={64} />
                        <Image alt="Dog 2" src={dog2} width={64} height={64} />
                        <Image alt="Dog 3" src={dog3} width={64} height={64} />
                        <Image alt="Dog 4" src={dog4} width={64} height={64} />
                    </div>
                </div>
                <div className="relative">
                    <div className="border-solid border-8 border-black rounded-lg max-w-fit">
                        {children}
                    </div>
                    {status === Status.NewGame || status === Status.Lost ? <GameScoreboard score={status === Status.Lost ? score : undefined} /> : null}
                </div>
                <div className="m-auto">
                    <span className="font-sans">
                        ☛ <b>Dogs</b> eat <b>sausages</b> and <b>cats</b> love <b>tuna</b>. <br />
                        ☛ <b>Touch the edges</b> of the play-area to <b>change direction</b>. <br />
                        ☛ <b>Touch the center</b> to swap between <b>cat or dog</b>. <br />
                        ☛ Alternatively, use the <b>arrow-keys</b> to <b>change the direction</b>. <br />
                        ☛ With <b>space</b> control can be changes between <b>dog or cat</b>.
                    </span>
                </div>
            </div>
        </div>
    )
};

export default GameContainer;
