// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from 'next'
import { Score } from "../../models";

type Error = {
    message: string;
};

export default async function handler(
    req: NextApiRequest,
    res: NextApiResponse<Score[] | Error>
) {
    let recentScore: Score | undefined;
    if (req.method === 'POST') { // If method was POST, we also add a new score!
        const {
            score,
            username
        } = req.body;
        if (typeof score !== "number" || typeof username !== "string") {
            res.status(400).send({ message: 'Required arguments not provided!' });
            return;
        }
        Date.now()
        recentScore = await Score.create({
            username,
            score,
        });
        recentScore = recentScore.toJSON()
    }

    // We always return the scores...
    const results = await Score.findAll({
        limit: 10,
        order: [
            ['score', 'DESC'], // We sort by score
        ],
    });
    const scores = results.map((s) => s.toJSON());

    // Let's see if recentScore was set, and if so, we check if we still need to
    // add it to our return values
    if (recentScore !== undefined) {
        if (scores.findIndex((s) => s.id === recentScore!.id) < 0) {
            // Score is not listed yet
            scores.pop(); // So let's remove last element and insert it
            scores.push(recentScore);
        }
    }

    // Let's mark the recent score
    const scoresWithMarker = scores.map((s) => ({ recent: s.id === recentScore?.id, ...s }));

    res.status(200).json(scoresWithMarker);
}
